FROM docker4gis/angular:341 as builder

FROM docker4gis/serve:344
ENV SINGLE=true
RUN rm -rf /wwwroot

# TODO: edit to set the correct dist path:
COPY --from=builder /src/dist/ /wwwroot
