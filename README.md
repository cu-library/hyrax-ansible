STATUS: ALPHA

# hyrax-ansible
Ansible playbook for installing a Hyrax-based institutional repository.

## Introduction and Assumptions

This repository is a starting point for teams planning on running Hyrax-based IRs in production.
The idea is similar to https://github.com/Islandora-Devops/claw-playbook

These roles install the dependences for Hyrax (Solr, Ruby, Redis, PostreSQL, Node.js, Nginx, FITS, FFmpeg, and Fedora 4) then installs a Hyrax based application from a Github repository using Ansistrano.

This playbook is being tested against CentOS 7, Debian 9, Debian 10, Ubuntu 18.04 and Ubuntu 20.04. The Vagrantfile used is available at https://github.com/cu-library/hyrax-ansible-testvagrants.

All roles assume services (Nginx, Fedora 4, PostgreSQL) are installed on one machine and communicate using UNIX sockets or the loopback interface. For large deployments, you'll want to edit these roles so that services are deployed on different machines and that communication between them is encrypted.

These roles also do not create admin users. See https://github.com/samvera/hyrax/wiki/Making-Admin-Users-in-Hyrax. But it does run the following to set up basic data structures needed for Hyrax / Hyku.

`bundle exec rails hyrax:default_collection_types:create hyrax:default_admin_set:create hyrax:workflow:load`

These roles assume that an external SMTP server will be used. Some environments might want to use use a local mail transfer agent. More information can be found in the Hyrax management guide: https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide#mailers.

`install_hyrax_on_localhost.yml` is a test playbook which runs the provided roles against localhost.

## Setup, Usage and Deployment
Initial provisioning of Linux boxes is left outside the scope of this project. We assume a working CentOS 7, Debian 9/10 or Ubuntu 18.04/20.04 system. If you are installing this repository on the box itself, check out the repository in to a local directory, verify the variables in `vars/common.yml`, then do the following:

```sh
ansible-galaxy install -r requirements.yml
ansible-playbook install_hyrax_on_localhost.yml
```

After initial setup you can use `ansible-playbook deploy.yml` and `ansible-playbook rollback.yml` to deploy and rollback various versions of the application code

### Carleton University Library's Use Of This Repo

Carleton University Library forked https://github.com/samvera/hyku and this repository into two private Github repositories. In those forks, we changed variables in the `common.yml` file including `ansistrano_git_repo` to point to our fork of Hyku. We moved the sensitive variables to an Ansible vault. Finally, we included the inventory and Ansible configuration needed to deploy on virtual machines in our environment.

## "Production Ready"

What does production ready mean? A production ready instance of Hyrax should be secure. It should be regularly backed-up. It should be easy to update. Finally, it should have good performance.

### Security

INCOMPLETE

The services running within the VM should ensure data is protected from unauthorized access and modification. If one were to gain access to a nonprivileged Linux user account, one should not be able to access or modify any IR data. *Currently, this is not true of these roles. Some services are available to any Linux user.*

### Backups

NEEDS TESTING, FEEDBACK WELCOME

The `hyrax` role has three backup scripts. They are copied to the /etc/cron.daily, /etc/cron.weekly, and /etc/cron.monthly directories, so the exact time they run is dependent on the distribution and system configuration.

Daily, Fedora 4 repository data (using the `fcr:backup` REST endpoint), PostgreSQL data (using `pg_dumpall`), the Redis `/var/lib/redis/dump.rdb` file and the Hyrax root directory are copied, tar'd together, and compressed. The resulting backup file has a datestamp and a MD5 checksum added to the filename. The daily backups reside in the `hyrax_backups_directory`/daily directory. As well as performing the backup, the daily backup script deletes any files in the daily directory that are older than 7 days old.

Weekly, a script moves the oldest daily backup to the `hyrax_backups_directory`/weekly directory. The weekly script also deletes files in the weekly directory that are older than 31 days old.

Monthly, a script moves the oldest weekly backup to the `hyrax_backups_directory`/monthly directory. The weekly script also deletes files in the monthly directory that are older than 365 days old.

For large deployments, this amount of backups might overwhelm local storage. It is recommended that the backup schedule and retention periods be tailored for your deployment.

It is up to local system administrators to copy backup data to a NAS or SAN, tape, or to cloud storage like Amazon Glacier or OLRC.

### Updates

NEEDS TESTING, FEEDBACK WELCOME

Where possible, it should be easy to keep a production server up-to-date. This means these roles should utilize well-known package repositories and package management tools when possible. Roles should be as idempotent and 'low impact' as possible, to encourage system administrators to run them regularly. Local modifications to community code should be minimal. These roles should not overwrite local changes and customizations.

### Performance

NEEDS TESTING, FEEDBACK WELCOME

These roles should install Hyrax so that it has good performance (max 500ms for most requests) on a "medium sized" server (4 core, 4GB RAM) when being used for typical workloads (documents and images, some multimedia, less than 10,000 digital objects). Community recommended software versions and configuration should be used.

## Software versions

Some software in the provided roles is installed using yum or apt from the default distribution repositories. The software version will depend on the distribution and release. For example, version 7 or 8 of Tomcat might be installed. For Java, OpenJDK version 8 is used.

Nginx is installed using that project's pre-built packages for the stable version, and not the default distribution repositories.

Node.js latest version 10.x is installed using the NodeSource repositories.

Some software is installed at a specific version:

* Fedora Repository 4.7.5 (Set using `fedora4_version` variable.)
* Solr 7.7.3 (Set using `solr_version` variable.)
* Ruby 2.7.2 (Set using `ruby_version` variable.)
* FFmpeg 4.3.1 (Set using `ffmpeg_version` variable.)
* FITS 1.5.0 (Set using `fits_version` variable.)

FFmpeg is built with:

* cmake: 3.19.1 (Set using `cmake_version` variable.)
* NASM 2.15.05 (Set using `nasm_version` variable.)
* Yasm 1.3.0 (Set using `yasm_version` variable.)
* x264: 20191217-2245-stable (Set using `x264_version` variable.)
* x265: 3.4 (Set using `x265_version` variable.)
* fdk-aac: 2.0.1 (Set using `fdk_aac_version` variable.)
* lame: 3.100 (Set using `lame_version` variable.)
* opus: 1.3.1 (Set using `opus_version` variable.)
* libogg: 1.3.4 (Set using `libogg_version` variable.)
* libvorbis: 1.3.7 (Set using `libvorbis_version` variable.)
* aom: c52d9602fef3094c880520b5af621ad8db0813fd (Set using `aom_version` variable.) Falling back to using a commit instead of a tagged release. The tarballs from https://aomedia.googlesource.com/aom/ are generated when requested for a particular tag. They are not stable releases, and as such do not have stable checksums. A checksum is not provided.
* libvpx: 1.9.0 (Set using `libvpx_version` variable.)
* libass: 0.15.0 (Set using `libass_version` variable.)

## Variables

|Variable|Notes|Default|
|---|---|---|
|`ansistrano_deploy_to` | Path where Hyrax app is deployed. | `/var/www/hyrax` |
|`ansistrano_keep_releases` | Number of old releases to keep. | `5` |
|`ansistrano_shared_paths` | Array of shared paths that are symlinked to each release. | `log, public/system, tmp, vendor/bundle` |
|`ansistrano_shared_files` | Array of shared files that are symlinked to each release. | `config/database.yml, config/puma.rb, config/initializers/mail.rb`|
|`ansistrano_deploy_via` | Ansistrano tool for depoyment, can by rsync or git. | `git` |
|`ansistrano_git_repo` | Repo of the application to deploy | `https://github.com/samvera/hyku.git` |
|`ansistrano_git_branch` | What version of the repository to check out. This can be the full 40-character SHA-1 hash, the literal string HEAD, a branch name, or a tag name. | `master` |
|`ansistrano_git_identity_key_path` | If specified this file is copied over and used as the identity key for the git commands, path is relative to the playbook in which it is used ||
|`aom_version` | The version of aom to download. Used to build FFmpeg. | `c52d9602fef3094c880520b5af621ad8db0813fd` |
|`bundler_version` | The version of the gem bundler to install. | `2.2.9` |
|`cmake_checksum` | Verify the cmake-`3.19.1`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:587fb2d882214511f4b260329800de7903eba7827498f06a0dee234ed579bdc3` |
|`cmake_version` | The version of cmake to download. Used to build aom library for FFmpeg. | `3.19.1` |
|`fdk_aac_checksum` | Verify the fdk-aac-`2.0.1`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:a4142815d8d52d0e798212a5adea54ecf42bcd4eec8092b37a8cb615ace91dc6` |
|`fdk_aac_version` | The version of fdk-aac to download. Used to build FFmpeg. | `2.0.1` |
|`fedora4_checksum` | Verify the fcrepo-webapp-`4.7.5`.war file, used by `get_url` module. Format: `<algorithm>:<checksum>` | `sha256:df37bdbc41879e1a1697acbf409f19df837351f7179a03c98a38b9f71f6bc173` |
|`fedora4_postgresqldatabase_user_password` | **Secure.** The password used by fedora4 to connect to Postgresql. | `insecure_password` |
|`fedora4_version` | The version of Fedora 4 to download. | `4.7.5` |
|`ffmpeg_checksum` | Verify the ffmpeg-`4.3.1`.tar.bz2 file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:f4a4ac63946b6eee3bbdde523e298fca6019d048d6e1db0d1439a62cea65f0d9` |
|`ffmpeg_compile_dir` | The directory where ffmpeg sources will be downloaded, unarchived, and compiled. | `/opt/ffmpeg` |
|`ffmpeg_version` | The version of FFmpeg to download. | `4.3.1` |
|`fits_checksum` | Verify the fits-`1.5.0`.zip file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:1378a78892db103b3a00e45c510b58c70e19a1a401b3720ff4d64a51438bfe0b` |
|`fits_version` | The version of FITS to download. | `1.5.0` |
|`hyrax_backups_directory` | The location where backup files will be created. | `/var/backups` |
|`hyrax_database_pool_size` | The size of the database pool. | `30` |
|`hyrax_from_email_address ` | The email address to use for the from field when sending emails from Hyrax. | `test@example.com` |
|`hyrax_postgresqldatabase_user_password` | **Secure.** The password used by hyrax to connect to Postgresql. | `insecure_password` |
|`hyrax_secret_key_base` | **Secure.** The secret used by Rails for sessions etc. | `insecure_key_base` |
|`hyrax_smtp_address` | Rails smtp address. | `smtp.example.com` |
|`hyrax_smtp_port` | Rails smtp port. | `25` |
|`hyrax_smtp_domain` | Rails smtp domain for mailer. | `example.com` |
|`hyrax_smtp_user_name` | **Secure.** Rails smtp username for mailer. | `change_this_username` |
|`hyrax_smtp_password` | **Secure.** Rails smtp password for mailer. | `insecure_password` |
|`hyrax_smtp_authentication` | Rails authentication method for mailer. | `False` |
|`hyrax_smtp_enable_starttls_auto` | Rails starttls setting for mailer. | `False` |
|`hyrax_smtp_openssl_verify_mode` | Rails openssl verify mode for mailer. | `False` |
|`hyrax_smtp_ssl` | Rails ssl setting for mailer. | `False` |
|`hyrax_smtp_tls` | Rails tls setting for mailer. | `False` |
|`imagemagick_package` | **Per-Distro** The name used by the `package` module when installing ImageMagick. ||
|`java_openjdk_package` | **Per-Distro** The name used by the `package` module when installing the Java JDK. ||
|`lame_checksum` | Verify the lame-`3.100`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e` |
|`lame_version` | The version of lame to download. Used to build FFmpeg. | `3.100` |
|`libass_checksum` | Verify the libass-`1.3.0`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:232b1339c633e6a93c153cac7a483e536944921605f35fcbaedc661c62fb49ec` |
|`libass_version` | The version of libass to download. Used to build FFmpeg. | `0.15.0` |
|`libogg_checksum` | Verify the libogg-`1.3.4`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:fe5670640bd49e828d64d2879c31cb4dde9758681bb664f9bdbf159a01b0c76e` |
|`libogg_version` | The version of libogg  to download. Used to build FFmpeg. | `1.3.4` |
|`libvorbis_checksum` | Verify the libvorbis-`1.3.7`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:0e982409a9c3fc82ee06e08205b1355e5c6aa4c36bca58146ef399621b0ce5ab` |
|`libvorbis_version` | The version of libvorbis  to download. Used to build FFmpeg. | `1.3.7` |
|`libvpx_checksum` | Verify the libvpx-`1.9.0`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:d279c10e4b9316bf11a570ba16c3d55791e1ad6faa4404c67422eb631782c80a` |
|`libvpx_version` | The version of libvpx to download. Used to build FFmpeg. | `1.9.0` |
|`make_jobs` | Sets an environment variable MAKEFLAGS to '-j X' in the test playbook. | `2` |
|`nasm_checksum` | Verify the nasm-`2.15.05`.tar.bz2 file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:3c4b8339e5ab54b1bcb2316101f8985a5da50a3f9e504d43fa6f35668bee2fd0` |
|`nasm_version` | The version of NASM to download. Used to build FFmpeg. | `2.15.05` |
|`opus_checksum` | Verify the opus-`1.3.1`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:65b58e1e25b2a114157014736a3d9dfeaad8d41be1c8179866f144a2fb44ff9d` |
|`opus_version` | The version of opus to download. Used to build FFmpeg. | `1.3.1` |
|`postgresql_contrib_package` | **Per-Distro** The name used by the `package` module when installing Postgresql's additional features. ||
|`postgresql_devel_package` | **Per-Distro** The name used by the `package` module when installing the Postgresql C headers and other development libraries. ||
|`postgresql_server_package` | **Per-Distro** The name used by the `package` module when installing the Postgresql server. ||
|`puma_web_concurency` | Number of Puma processes to start. | `4` |
|`python_psycopg2_package` | **Per-Distro** The name used by the `package` module when installing the Python Postgresql library (used by Ansible). ||
|`redis_package` | **Per-Distro** The name used by the `package` module when installing Redis. ||
|`ruby_install_version` | The version of ruby-install to download and install. | `0.7.1` |
|`ruby_install_checksum` | Verify the ruby-instal tarball. | `sha256:2a082504f81b6017e8f679f093664fff9b6a282f8df4c9eb0a200643be3fcb56` |
|`ruby_tarbz2_sha256_checksum` | Verify the ruby-`2.7.2`.tar.bz2 file, used by `ruby-install`. Format: `<checksum>` | `65a590313d244d48dc2ef9a9ad015dd8bc6faf821621bbb269aa7462829c75ed` |
|`ruby_version` | The version of Ruby to download and install. | `2.7.2` |
|`sidekiq_threads` | Tune the number of sidekiq threads that will be started. | `10` |
|`solr_checksum` | Verify the solr-`7.7.3`.tgz file, used by `get_url` module. Format: `<algorithm>:<checksum>` | `sha512:ca9200c18cc19ab723fd4d10f257e27eb81dc8bc33401ebc4eb99178faf4033a2684f0f8b12ae7b659cfeb0f4c9d9e24aaac518a4e00fd28b69854a359a666ed` |
|`solr_mirror` | The mirror to use when downloading Solr. | `https://mirror.csclub.uwaterloo.ca/apache` |
|`solr_version` | The version of Solr to download. | `7.7.3` |
|`tomcat_admin_package` | **Per-Distro** The name used by the `package` module when installing the tomcat manager webapps. ||
|`tomcat_fedora4_conf_path` | **Per-Distro** The path for the configuration file which sets JAVA_OPTS for Fedora4. ||
|`tomcat_fedora4_war_path` | **Per-Distro** The path at which the fedora4 war file will be copied. ||
|`tomcat_group` | **Per-Distro** The primary group for the tomcat service user. ||
|`tomcat_package` | **Per-Distro** The name used by the `package` module when installing tomcat. ||
|`tomcat_service_name` | **Per-Distro** The name of the tomcat service. ||
|`tomcat_user_password` | **Secure.** The password used to build the tomcat-users.xml file. | `insecure_password` |
|`tomcat_user` | **Per-Distro** The user which runs the tomcat service. ||
|`tomcat_users_conf_path` | **Per-Distro** The path for tomcat-users.xml. ||
|`x264_checksum` | Verify the x264-snapshot-`20191217-2245-stable`.tar.bz2 file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:b2495c8f2930167d470994b1ce02b0f4bfb24b3317ba36ba7f112e9809264160` |
|`x264_version` | The version of x264 to download. Used to build FFmpeg. | `20191217-2245-stable` |
|`x265_version` | The version of x265 to download. Used to build FFmpeg. | `3.4` |
|`yasm_checksum` | Verify the yasm-`1.3.0`.tar.gz file, used by `get_url`. Format: `<algorithm>:<checksum>` | `sha256:3dce6601b495f5b3d45b59f7d2492a340ee7e84b5beca17e48f862502bd5603f` |
|`yasm_version` | The version of Yasm to download. Used to build FFmpeg. | `1.3.0` |

**Per-Distro**: Different value for different OSs. The test playbook uses

```
vars_files:
    - "vars/common.yml"
    - "vars/{{ ansible_distribution }}.yml"
```

and per-distribution variable files to provide different variables for different distributions.

**Secure**: Variables which should be different per-host and stored securely using Ansible Vaults or a tool like Hashicorp Vault. The test playbook insecurely puts these variables in `vars/common.yml`.


