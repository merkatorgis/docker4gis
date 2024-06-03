FROM docker4gis/aspdotnet-builder as builder

FROM docker4gis/aspdotnet

COPY --from=builder /app .
