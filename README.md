Reddit::Client with Oauth support for the required switch on August 3, 2015. This version also contains a function to send private messages, and a bug fix that was preventing the me() function from working. The original Reddit::Client can be found here: https://github.com/jsober/Reddit-API. 

Unlike the old username/password authentication where you could plug in any valid username/password, Reddit's Oauth authentication **will only work with accounts that have developer permission on the app**<sup>1</sup>. You can register an app and add developers on your preferences/apps page: https://www.reddit.com/prefs/apps.


# Usage 

```
# Create Reddit::Client object
my $reddit = Reddit::Client->new(
        session_file => 'session_data.json',
        user_agent   => 'myUserAgent v3.4',
);  
my $client_id  = "DFhtrhBgfhhRTd";
my $secret     = "KrDNsbeffdbILOdgbgSvSBsbfFs";
my $username   = "reddit-username";
my $password   = "reddit-password";

# Get token. 
$reddit->get_token($client_id, $secret, $username, $password);

##############################################
# Send private message
##############################################
my $result = $reddit->send_message(
	to      => 'earth-tone',
	subject => 'test',
	text    => 'i can haz PMs?'
);

##############################################
# Get all comments from a subreddit or multi
# -Reddit's API now defaults to 25 with max of 100
##############################################
my $cmts = $reddit->get_subreddit_comments(
	subreddit => 'all+test',
	limit => 25,
);

##############################################
# Get your account information
##############################################
my $me = $reddit->me();
use Data::Dumper;
print Dumper($me);
```

The authorization token lasts for 1 hour. If your script runs continuously for more than an hour, it will be refreshed before making the next request.

While it is possible to get "permanent" tokens, that term is misleading because you still need to get a temporary token every time the script runs, which will also expire after an hour. They are intended for applications that are doing things on a user's behalf ("web" and "installed" app types). There is no benefit to supporting this for a "script" type app, and Reddit::Client didn't, so this doesn't, although I may add support if there is demand.

# Installation
The Reddit directory can be dropped right onto the Reddit directory in your existing Reddit::Client installation, which is probably somewhere like /usr/local/share/perl/5.14.2/Reddit. The installer resumably works but is untested.

---

<sup>1</sup> For "script" type apps, which your Perl script presumably is if you were using the original Reddit::Client. "Script" type apps log into an account using a username and password.

The other two app types are "web app" and "installed". They do things on behalf of a user without a password, and require a user to give them permission first. The best example is an Android app where you click "Allow" to let it act for your Reddit account, although you may have seen this type of confirmation before on a web page too (and that would be the "web app" type). Reddit::OauthClient doesn't support them, although I may add support if there is demand.
