FROM docker4gis/angular:661 AS builder

FROM docker4gis/serve:460
ENV SINGLE=true
RUN rm -rf /wwwroot

# TODO: edit to set the correct dist path:
COPY --from=builder /src/dist/app/ /wwwroot
