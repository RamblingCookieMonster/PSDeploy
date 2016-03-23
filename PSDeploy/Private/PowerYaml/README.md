PowerYaml
-

PowerYaml is a wrapper around [Yaml.Net]() library. The wrapper was originally developed by [Scott Muc](https://github.com/scottmuc) and [Manoj Mahalingam](https://github.com/manojlds).

Sample
-	

	@"
	---
	# An employee record
	name: Example Developer
	job: Developer
	skill: Elite
	"@ | ConvertFrom-Yaml	

Results
-
	name              job       skill
	----              ---       -----
	Example Developer Developer Elite

Import-Yaml
-
Does Files

	dir *.yml|Import-Yaml

Results
-
	name              job       skill     
	----              ---       -----     
	Example Developer Developer Elite     
	John Doe          Developer PowerShell

On GitHub [Yaml.Net](https://github.com/aaubry/YamlDotNet)