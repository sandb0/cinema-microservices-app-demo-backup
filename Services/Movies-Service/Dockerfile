FROM node:alpine

ENV APP=/home/application

WORKDIR $APP

COPY package.json .
RUN yarn
COPY . $APP

CMD ["yarn", "dev"]