# tweets-to-html
Tweets to HTML

## Setup

```
$ bundle install --path vendor/bundle
```

## Examples

```
$ bundle exec ruby t2h.rb
```

```
$ bundle exec ruby t2h.rb --auth=../my-auth.json --image-size=600 > ../output.html
```

## Help

```
$ ruby t2h.rb --help
Usage: t2h [options]
  --auth=auth.json             the auth JSON file
  --template=template.erb      the template file
  --name=screen_name           the screen_name of the user
  --count=200                  the number of tweets
  --image-size=small           thumb, small, medium, large or 640 and so (the length of the long edge)
```

