# Етап 1: Відновлення залежностей та публікація застосунку
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS builder
WORKDIR /src

COPY *.csproj ./
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# Етап 2: Runtime-образ без SDK та запуск від non-root користувача
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup -u 10001

COPY --from=builder --chown=10001:10001 /app/publish ./

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
USER 10001

ENTRYPOINT ["dotnet", "DormHelper.Api.dll"]
