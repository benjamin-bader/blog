all: blog

server:
	hugo server --buildDrafts -w

blog:
	hugo --buildDrafts -d public-blog -b http://bendb.com/
	find public-blog -type d -print0 | xargs -0 chmod 0755
	find public-blog -type f -print0 | xargs -0 chmod 0644

deploy: blog
	rsync -avz -e "ssh -i /home/ben/.ssh/ben_azure -o StrictHostKeyChecking=no" --delete public-blog/ bendb.cloudapp.net:/home/ben/www

clean:
	rm -rf public-blog

.PHONY: all server blog deploy clean

