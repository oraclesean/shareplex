# shareplex
A repository of Shareplex administration scripts.

Shareplex is a data replication product by Dell (purchased from Quest Software) that performs asynchronous replication
of Oracle databases. The target of replication is another Oracle database, a JMS target, XML or SQL Server.

After implementing Shareplex I discovered that much of the implementation guides provided by Dell were light on substance.
I found the default scripts supplied by Dell to be highly dependent on hardcoded values, paths, and generally not very 
extensible, particularly for use in a RAC environment.

This collection of scripts is a set of solutions I developed to manage and monitor a Shareplex environment running on RAC.
It eliminates hardcoding by accepting command-line parameters or calling environment configurations to do the custom work,
meaning the scripts should be portable across any *nix environment and eliminate the need for you to go in and edit the 
actual code.

Default Dell scripts are prefixed sp_*. I define custom scripts with the spx* prefix for clarity.

Example configurations are included.

Enjoy!
