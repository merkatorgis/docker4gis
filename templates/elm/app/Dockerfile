FROM docker4gis/elm:238 as builder

FROM docker4gis/serve:344
ENV SINGLE=true
RUN rm -rf /wwwroot
COPY --from=builder /elm/build /wwwroot
