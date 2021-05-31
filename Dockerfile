FROM scalingo/scalingo-18

ADD . buildpack

ADD .env /env/.env
RUN buildpack/bin/env.sh /env/.env /env
RUN buildpack/bin/compile /build /cache /env
RUN rm -rf /app/nocodb
RUN rm -rf /app/nodejs
RUN cp -rf /build/nodejs /app/nodejs
RUN cp -rf /build/nocodb /app/nocodb

EXPOSE ${PORT}

ENTRYPOINT [ "/app/nocodb/run", "/app/nocodb", "/app/nodejs" ]