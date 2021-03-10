FROM docker4gis/angular:302 as builder

FROM docker4gis/serve:297
ENV SINGLE=true
RUN rm -rf /wwwroot

# TODO: edit to set the correct dist path:
COPY --from=builder /src/dist/app/ /wwwroot
