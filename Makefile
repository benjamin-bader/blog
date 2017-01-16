all: blog

server:
	hugo server --buildDrafts -w

blog: .FORCE
	hugo --buildDrafts -d public-blog -b http://bendb.com/
	find public-home -type d -print0 | xargs -0 chmod 755
	find public-home -type f -print0 | xargs -0 chmod 644

deploy: blog
	rsync -avz -e "ssh -i /home/ben/.ssh/ben_azure -o StrictHostKeyChecking=no" --delete public-blog/ bendb.cloudapp.net:/home/ben/www

.FORCE:
