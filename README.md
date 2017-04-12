# Correspondence Tools - Staff
[![Build Status](https://travis-ci.org/ministryofjustice/correspondence_tool_staff.svg?branch=develop)]
(https://travis-ci.org/ministryofjustice/correspondence_tool_staff) 
[![Code Climate](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/gpa.svg)]
(https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)
[![Test Coverage](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/coverage.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/coverage) [![Issue Count](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/issue_count.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)


A simple application to allow internal staff users to answer correspondence. 

## Local development

### Clone this repository change to the new directory

```bash
$ git clone git@github.com:ministryofjustice/correspondence_tool_staff.git
$ cd correspondence_tool_staff
```

### Installing Dependencies

<details>
<summary>Latest Version of Ruby</summary>

Install the latest version of ruby as defined in `.ruby-version`.

With rbenv (make sure you are in the repo path):

```
$ rbenv install
$ gem install bundler
```
</details>

<details>
<summary>Installing Postgres 9.5.x</summary>

We use version 9.5.x of PostgreSQL to match what we have in the deployed
environments, and also because the `structure.sql` file generated by PostgreSQL
can change with every different version.

```
$ brew install postgresql@9.5
```
</details>

<details>
<summary>Installing Latest XCode Stand-Alone Command-Line Tools</summary>

May be necessary to ensure that libraries are available for gems, for example
Nokogiri can have problems with `libiconv` and `libxml`.

```
$ xcode-select --install
```
</details>

<details>
<summary>Installing PhantomJS</summary>

We use the [Poltergeist JS driver](https://github.com/teampoltergeist/poltergeist)
for Capybara tests, which requires PhantomJS. Install this with your favourite
package manager, e.g.:

```
$ brew install phantomjs
```

</details>

### Libreoffice

Libreoffice is used to convert documents to PDF's so that they can be viewed in a browser.
In production environments, the installation of libreoffice is taken care of during the build
of the docker container (see the Dockerfile).

In localhost dev testing environments, libreoffice needs to be installed using homebrew, and then 
the following shell script needs to created with the name ```/usr/local/bin/soffice```:


```
cd /Applications/LibreOffice.app/Contents/MacOS && ./soffice $1 $2 $3 $4 $5 $6
```

The above script is needed by the libreconv gem to do the conversion.

### Rake Tasks 

Last two rake demo tasks are not required for production service.
 
```
$ rails db:create
$ rails db:migrate
$ rails db:seed
$ rails users:demo_entries
$ rails cases:demo_entries
```

### Emails

Emails are sent using
the [GOVUK Notify service](https://www.notifications.service.gov.uk).
Configuration relies on an API key which is not stored with the project, as even
the test API key can be used to access account information. To do local testing
you need to have an account that is attached to the "Track a query" service, and
a "Team and whitelist" API key generated from the GOVUK Notify service website.
See the instructions in the `.env.example` file for how to setup the correct
environment variable to override the `govuk_notify_api_key` setting.

The urls generated in the mail use the `cts_email_host` and `cts_mail_port`
configuration variables from the `settings.yml`. These can be overridden by
setting the appropriate environment variables, e.g.

```
$ export SETTINGS__CTS_EMAIL_HOST=localhost
$ export SETTINGS__CTS_EMAIL_PORT=5000
```

### Uploads

Responses and other case attachments are uploaded directly to S3 before being
submitted to the application to be added to the case. Each deployed environment
has the permissions is needs to access the uploads bucket for that environment.
In local development, uploads are place in the
[correspondence-staff-case-uploads-testing](https://s3-eu-west-1.amazonaws.com/correspondence-staff-case-uploads-testing/)
bucket.

You'll need to provide access credentials to the aws-sdk gems to access
it, there are two ways of doing this:

#### Using credentials attached to your IAM account

If you have an MoJ account in AWS IAM, you can configure the aws-sdk with your access and secret key by placing them in the `[default]` section in `.aws/credentials`:

1. [Retrieve you keys from your IAM account](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html)<sup>[1](#user-content-footnote-aws-access-key)</sup> if you don't have them already.
2. [Place them in `~/.aws/credentals`](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html)

#### Using shared credentials

Alternatively, if you don't have an AWS account with access to that bucket, you
can get access by using an access and secret key specifically generated for
testing:

1. Retrieve the 'Case Testing Uploads S3 Bucket' key from the Correspondence
   group in Rattic.
2. [Use environment variables to configure the AWS SDK](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html#aws-ruby-sdk-credentials-environment)
   locally.



# Footnotes

<a name="footnote-aws-access-key">1</a>: When following these instructions, I had to replace step 3 (Continue to Security Credentials) with clicking on *Users* on the left, selecting my account from the list there, and then clicking on "Security Credentials".
