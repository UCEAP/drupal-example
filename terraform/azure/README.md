After running `terraform apply`, there are a couple of manual steps remaining:


## Turn off TLS requirement for MySQL

> to be fixed by adding TLS to the Drupal database settings

```bash
az mysql flexible-server parameter set \
	--resource-group `terraform output -raw resource_group_name` \
	--server-name `terraform output -raw database_name` \
	--name require_secure_transport --value OFF
```

## Get Publish Profile from Azure and set in GitHub Actions

> to be fixed with https://github.com/hashicorp/terraform-provider-azurerm/issues/8739#issuecomment-906662463
```bash
az webapp deployment list-publishing-profiles \
	--resource-group `terraform output -raw resource_group_name` \
	--name `terraform output -raw app_service_name` --xml | \
	gh secret set AZURE_WEBAPP_PUBLISH_PROFILE \
		--repo UCEAP/drupal-example \
		--app actions
```
