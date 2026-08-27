# Workspace orchestration for ecommerce-msa + ecommerce-frontend.
# From repo root: cp ecommerce-msa/.env.example ecommerce-msa/.env && make up

.PHONY: help up down infra-up infra-stop infra-reset build apps apps-stop apps-wait \
	apps-restart-payment debezium package run-jar stripe-listen frontend check-prereqs

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPTS := $(ROOT)scripts

help:
	@echo "Targets:"
	@echo "  make up                 Infra + build + apps + debezium"
	@echo "  make down               Stop apps + stop infra containers"
	@echo "  make infra-up|stop|reset"
	@echo "  make build              mvn clean install -DskipTests"
	@echo "  make apps|apps-stop|apps-wait|apps-restart-payment"
	@echo "  make debezium           Register Debezium connectors"
	@echo "  make package            mvn package -DskipTests"
	@echo "  make run-jar SERVICE=payment"
	@echo "  make stripe-listen      Foreground listen (debug); make apps auto-handles whsec"
	@echo "  make frontend           bun run dev"
	@echo "  make check-prereqs"

check-prereqs:
	@bash $(SCRIPTS)/check-prereqs.sh

up:
	@bash $(SCRIPTS)/stack-up.sh

down:
	@bash $(SCRIPTS)/stack-down.sh

infra-up:
	@bash $(SCRIPTS)/infra-up.sh

infra-stop:
	@bash $(SCRIPTS)/infra-stop.sh

infra-reset:
	@bash $(SCRIPTS)/infra-reset.sh

build:
	@bash $(SCRIPTS)/apps-build.sh

apps:
	@bash $(SCRIPTS)/apps-run.sh

apps-stop:
	@bash $(SCRIPTS)/apps-stop.sh

apps-wait:
	@bash $(SCRIPTS)/apps-wait.sh

apps-restart-payment:
	@bash $(SCRIPTS)/apps-restart-payment.sh

debezium:
	@bash $(SCRIPTS)/debezium-setup.sh

package:
	@bash $(SCRIPTS)/package-jars.sh

run-jar:
	@SERVICE="$(SERVICE)" bash $(SCRIPTS)/run-jar.sh $(SERVICE)

stripe-listen:
	@bash $(SCRIPTS)/stripe-listen.sh

frontend:
	@bash $(SCRIPTS)/frontend-dev.sh
