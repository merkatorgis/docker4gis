FROM docker4gis/angular:latest as builder

FROM docker4gis/serve:249
ENV SINGLE=true
RUN rm -rf /wwwroot

# TODO: edit to set the correct dist path:
COPY --from=builder /src/dist/app/ /wwwroot
