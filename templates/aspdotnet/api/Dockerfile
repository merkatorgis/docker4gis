FROM docker4gis/aspdotnet-builder:488 as builder

FROM docker4gis/aspdotnet:488

COPY --from=builder /app .
