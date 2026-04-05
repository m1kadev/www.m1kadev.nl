FROM alpine:3
RUN apk add --no-cache elixir nginx git rust cargo nodejs npm
COPY nginx.conf /etc/nginx/nginx.conf

# setup folders
RUN mkdir -p /data/www
RUN adduser -D -g 'www' www
RUN chown -R www:www /var/lib/nginx

# build fxg
WORKDIR "/usr/local/fxg"
COPY fxg .
RUN cargo build --release
RUN cp target/release/fxg /usr/local/bin

# fetch deps
WORKDIR "/usr/local/app"
COPY pull-hljs.sh .
RUN ./pull-hljs.sh
WORKDIR "/usr/local/app/kethel"
COPY kethel/mix.exs kethel/mix.lock kethel/package.json kethel/package-lock.json .
RUN npm i

# build www.m1kadev.nl
WORKDIR "/usr/local/app"
COPY . .
WORKDIR "/usr/local/app/kethel"
RUN mix deps.get
RUN mix compile.rambo
RUN mix run main.exs -- ..
WORKDIR "/usr/local/app"
RUN cp -r build/* /data/www
WORKDIR "/data/www"

RUN chown -R www:www /data/www
RUN chmod -R 744 /data/www

# serve www.m1kadev.nl
CMD [ "nginx", "-c", "/etc/nginx/nginx.conf" ]