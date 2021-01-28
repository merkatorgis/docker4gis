FROM docker4gis/angular:latest as builder

FROM docker4gis/serve:249
ENV SINGLE=true
RUN rm -rf /wwwroot
# COPY --from=builder /woningvoorraad-tester/ /wwwroot
COPY --from=builder /src/dist/woningvoorraad/ /wwwroot