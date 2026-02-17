ARG IMAGE=intersystemsdc/irishealth-community
FROM $IMAGE

USER root
# Create the directory
WORKDIR /home/irisowner/dev
RUN chown irisowner:irisowner /home/irisowner/dev

# Copy everything from your local 'backend' folder into '/home/irisowner/dev'
COPY --chown=irisowner:irisowner . ./

USER irisowner

# Run setup
RUN iris start IRIS \
    && iris session IRIS < iris.script \
    && iris stop IRIS quietly