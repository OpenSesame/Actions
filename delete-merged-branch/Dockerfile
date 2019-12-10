FROM alpine:latest
LABEL maintainer="Jessica Frazelle <jess@linux.com>"

LABEL "com.github.actions.name"="Branch Cleanup"
LABEL "com.github.actions.description"="Delete the branch after a pull request has been merged"
LABEL "com.github.actions.icon"="activity"
LABEL "com.github.actions.color"="red"

RUN	apk add --no-cache \
	bash \
	ca-certificates \
	curl \
	jq

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
