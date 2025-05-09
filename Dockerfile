FROM ghcr.io/m1k1o/neko/nvidia-firefox:latest
COPY onstart.sh /root/onstart.sh
RUN chmod +x /root/onstart.sh
ENTRYPOINT ["/root/onstart.sh"]
