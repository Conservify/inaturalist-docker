all: terraform.tfplan

apply: terraform.tfplan
	terraform apply

terraform.tfplan:
	terraform get
	terraform plan -out=terraform.tfplan

clean:
	rm -f terraform.tfplan 

.PHONY: all apply clean
