# 构建阶段
FROM golang:1.23 AS builder

WORKDIR /app

COPY . .

RUN go mod tidy

RUN go build -o build/ main.go

RUN cp -r ./assets ./build/assets

FROM node:22 AS node_builder

WORKDIR /app

COPY . .

WORKDIR /app/web

RUN npm install

RUN npm run build

# 运行阶段
FROM debian:bookworm-slim

WORKDIR /app

# 从构建阶段复制构建产物
COPY --from=builder /app/build .

COPY --from=node_builder /app/web/dist ./frontend/build/web

# 暴露端口(根据您的应用需要修改)
EXPOSE 1323

# 运行应用
CMD ["./main"]