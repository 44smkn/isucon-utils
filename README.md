# isucon-utils

## Usage

### ローカルPC


```shell
# デプロイを行う
./client/deploy.sh 35.73.135.201 main

# alpを回して結果をhtmlにまとめる(s1はサーバ名)
./client/analyze.sh 35.73.135.201
```

### サーバ

```shell
# @isuconユーザのホームディレクトリ
git clone https://github.com/44smkn/isucon-utils.git
cd isucon-utils/server
webhook_url="<replace_your_webhook_url>"
./init.sh $webhook_url

cd $HOME/isuumo/webapp/go
git config --global user.name "isucon"
git config --global user.email "isucon@gmail.com"
git config --global credential.helper store
git config --global init.defaultBranch main

git init
git remote add origin https://github.com/<REPLACE_YOUR_ORG>/isucon12-qualify.git
git add .
git commit -m "Initial Commmit"
git branch -M main
git push -u origin main
```

pt-query-digestやalpの結果が見れるように、nginxのルーティングルールを変更する  
`sudo vim /etc/nginx/nginx.conf`

```sh
    server {
        listen 80;

        location / {
            proxy_pass http://localhost:1323;
        }
    }

    server {
        listen 9091;

        location / {
            root /www/data;
            index index.html;
        }
    }
```
