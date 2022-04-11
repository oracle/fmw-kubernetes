# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# This is a sample Dockerfile for supplying deployment artifacts in image

FROM busybox
ARG SOA_ARTIFACTS_ARCHIVE_PATH=/u01/sarchives
ARG OSB_ARTIFACTS_ARCHIVE_PATH=/u01/sbarchives
ARG USER=oracle
ARG USERID=1000
ARG GROUP=root
ENV SOA_ARTIFACTS_ARCHIVE_PATH=${SOA_ARTIFACTS_ARCHIVE_PATH}
ENV OSB_ARTIFACTS_ARCHIVE_PATH=${OSB_ARTIFACTS_ARCHIVE_PATH}
RUN adduser -D -u ${USERID} -G $GROUP $USER
COPY soa/ ${SOA_ARTIFACTS_ARCHIVE_PATH}/
COPY osb/ ${OSB_ARTIFACTS_ARCHIVE_PATH}/
RUN chown -R $USER:$GROUP ${SOA_ARTIFACTS_ARCHIVE_PATH}/ ${OSB_ARTIFACTS_ARCHIVE_PATH}/
USER $USER
