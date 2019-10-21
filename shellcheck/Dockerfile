# recommended in official repo https://github.com/koalaman/shellcheck
FROM koalaman/shellcheck-alpine

RUN apk add bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]