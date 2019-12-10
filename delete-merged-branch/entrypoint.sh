#!/bin/bash
set -e
set -o pipefail

if [[ -n "$TOKEN" ]]; then
	GITHUB_TOKEN=$TOKEN
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
	echo "Set the GITHUB_TOKEN env variable."
	exit 1
fi

URI=https://api.github.com
API_VERSION=v3
API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

# Github Actions uses either status code 0 for success or any other code for failure.
# Docs: https://help.github.com/en/articles/virtual-environments-for-github-actions#exit-codes-and-statuses
NO_BRANCH_DELETED_EXIT_CODE=${NO_BRANCH_DELETED_EXIT_CODE:-0}

main(){
	action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
	merged=$(jq --raw-output .pull_request.merged "$GITHUB_EVENT_PATH")

	echo "DEBUG -> action: $action merged: $merged"

	if [[ "$action" != "closed" ]] || [[ "$merged" != "true" ]]; then
	    exit "$NO_BRANCH_DELETED_EXIT_CODE"
	fi

	# delete the branch.
	ref=$(jq --raw-output .pull_request.head.ref "$GITHUB_EVENT_PATH")
	owner=$(jq --raw-output .pull_request.head.repo.owner.login "$GITHUB_EVENT_PATH")
	repo=$(jq --raw-output .pull_request.head.repo.name "$GITHUB_EVENT_PATH")
	default_branch=$(
		curl -XGET -fsSL \
			-H "${AUTH_HEADER}" \
 			-H "${API_HEADER}" \
			"${URI}/repos/${owner}/${repo}" | jq .default_branch
		)
	
	echo "Debug -> Received ref, owner and repo"

	if [[ "$ref" == "$default_branch" ]]; then
		# Never delete the default branch.
		echo "Will not delete default branch (${default_branch}) for ${owner}/${repo}, exiting."
		exit 0
	elif [[ "$ref" =~ ^(develop|master) ]]; then
		echo "Will not delete develop or master branch of repo, exiting."
		exit 0
	elif [[ "$ref" =~ ^(release|sprint)/\d+ ]]; then
		echo "Will not delete the release or sprint branch, exiting."
		exit 0
	fi
	http_response=$(
		curl -XGET --fail -fsSL \
		-H "${AUTH_HEADER}" \
		-H "${API_HEADER}" \
		"${URI}/repos/${owner}/${repo}/branches/${ref}"
	) || echo "fail"

	if [[ "$http_response" == "fail" ]]; then
		echo "Branch was already deleted, exiting."
		exit 0
	fi

	is_protected=$($http_response | jq .is_protected)

	if [[ "$is_protected" == "true" ]]; then
		# Never delete protected branches
		echo "Will not delete protected branch (${ref}) for ${owner}/${repo}, exiting."
		exit 0
	fi

	pulls_with_ref_as_base=$(
		curl -XGET -fsSL \
			-H "${AUTH_HEADER}" \
			-H "${API_HEADER}" \
			"${URI}/repos/${owner}/${repo}/pulls?state=open&base=${ref}"
	)
	has_pulls_with_ref_as_base=$(echo "$pulls_with_ref_as_base" | jq 'has(0)')

	if [[ "$has_pulls_with_ref_as_base" != false ]]; then
		# Do not delete if the branch is a base branch of another pull request
		pr=$(echo "$pulls_with_ref_as_base" | jq '.[0].number')
		echo "${ref} is the base branch of PR #${pr} for ${owner}/${repo}, exiting."
		exit 0
	fi

	echo "Deleting branch ref $ref for owner ${owner}/${repo}..."
	response=$(
		curl -XDELETE -sSL \
			-H "${AUTH_HEADER}" \
			-H "${API_HEADER}" \
			--output /dev/null \
			--write-out "%{http_code}" \
			"${URI}/repos/${owner}/${repo}/git/refs/heads/${ref}"
	)

	if [[ ${response} -eq 422 ]]; then
		echo "The branch is already gone!"
	elif [[ ${response} -eq 204 ]]; then
		echo "Branch delete success!"
 	else
		echo "Something unexpected happened!"
		exit "$NO_BRANCH_DELETED_EXIT_CODE"
	fi

	exit 0
}

main "$@"
