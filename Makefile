all: blog

server:
	hugo server --buildDrafts -w

blog:
	hugo --buildDrafts -d public-blog -b https://www.bendb.com/
	find public-blog -type d -print0 | xargs -0 chmod 0755
	find public-blog -type f -print0 | xargs -0 chmod 0644

deploy: blog
	rsync -avz --exclude-from=.rsync-excludes -e "ssh -i ~/.ssh/bendb_aws.pem -o StrictHostKeyChecking=no" --delete public-blog/ ubuntu@direct.bendb.com:/home/ubuntu/www

clean:
	rm -rf public-blog

.PHONY: all server blog deploy clean

