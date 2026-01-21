FROM ubuntu:22.04

# Build arguments for user ID and group ID
ARG USER_ID=1000
ARG GROUP_ID=1000

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install Python, pip, tini and other essentials
RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user 'me' with specified UID/GID
RUN groupadd -g ${GROUP_ID} me && \
    useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash me

# Switch to non-root user
USER me
WORKDIR /home/me/jupyter-work

# Copy requirements file
COPY --chown=me:me requirements.txt /tmp/requirements.txt

# Install Jupyter Notebook and any additional requirements
RUN pip3 install --no-cache-dir --user jupyter notebook && \
    if [ -f /tmp/requirements.txt ]; then \
        pip3 install --no-cache-dir --user -r /tmp/requirements.txt; \
    fi

# Add user's Python bin to PATH
ENV PATH="/home/me/.local/bin:${PATH}"

# Expose Jupyter port
EXPOSE 8888

# Use tini as init system for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start Jupyter Notebook server without browser, token, and password
CMD ["jupyter", "notebook", \
     "--ip=0.0.0.0", \
     "--port=8888", \
     "--no-browser", \
     "--NotebookApp.token=''", \
     "--NotebookApp.password=''", \
     "--NotebookApp.allow_origin='*'"]
