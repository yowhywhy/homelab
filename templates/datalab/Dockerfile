FROM python:3.12-slim-bookworm
RUN pip install --no-cache-dir jupyterlab==4.4.10 pandas==2.3.3 duckdb==1.4.1 pyarrow==22.0.0
RUN useradd --create-home --uid 1000 lab && mkdir /output && chown lab:lab /output
USER lab
WORKDIR /home/lab/work
EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
