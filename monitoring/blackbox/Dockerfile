FROM prom/blackbox-exporter:v0.16.0

COPY config.yml /etc/blackbox_exporter

EXPOSE 9115

ENTRYPOINT ["/bin/blackbox_exporter"]
CMD ["--config.file=/etc/blackbox_exporter/config.yml"]
