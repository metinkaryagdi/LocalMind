# Multi-stage Dockerfile for LocalMind .NET 9 Web API
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project files and restore dependencies
COPY ["LocalMind.Backend/LocalMind.Core/LocalMind.Core.csproj", "LocalMind.Backend/LocalMind.Core/"]
COPY ["LocalMind.Backend/LocalMind.Infrastructure/LocalMind.Infrastructure.csproj", "LocalMind.Backend/LocalMind.Infrastructure/"]
COPY ["LocalMind.Backend/LocalMind.Api/LocalMind.Api.csproj", "LocalMind.Backend/LocalMind.Api/"]

RUN dotnet restore "LocalMind.Backend/LocalMind.Api/LocalMind.Api.csproj"

# Copy full source code and publish
COPY . .
WORKDIR "/src/LocalMind.Backend/LocalMind.Api"
RUN dotnet publish "LocalMind.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime image stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
EXPOSE 5000

ENV ASPNETCORE_URLS=http://+:5000
ENV ConnectionStrings__DefaultConnection="Filename=/app/data/localmind_nosql.db;Connection=shared"
ENV Ollama__BaseUrl="http://ollama:11434"

# Create data folder for NoSQL database persistence
RUN mkdir -p /app/data

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "LocalMind.Api.dll"]
