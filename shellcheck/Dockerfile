# recommended in official repo https://github.com/koalaman/shellcheck
FROM koalaman/shellcheck-alpine

COPY entrypoint.sh /entrypoint.sh
RUN chmod +X /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]