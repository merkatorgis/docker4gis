FROM docker4gis/elm:355 as builder

FROM docker4gis/serve:460
ENV SINGLE=true
RUN rm -rf /wwwroot
COPY --from=builder /elm/build /wwwroot
