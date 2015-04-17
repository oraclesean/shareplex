# shareplex
A repository of Shareplex administration scripts.

Shareplex is a data replication product by Dell (purchased from Quest Software) that performs asynchronous replication
of Oracle databases. The target of replication is another Oracle database, a JMS target, XML or SQL Server.

The scripts installed with the product tend to rely on hardcoded values, paths, and aren't always extensible to use in a
RAC environment.

These scripts are solutions I developed to manage and monitor a Shareplex environment running on RAC. They  eliminate
hardcoding by accepting command-line parameters or calling environment configurations to do the custom work, meaning they
should be portable across any *nix environment and eliminate the need for you to go in and edit the actual code.

Default Dell scripts are prefixed sp_*. I define custom scripts with the spx* prefix for clarity in our environments.
