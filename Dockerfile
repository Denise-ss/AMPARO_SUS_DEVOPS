# GS 2026/2 - AMPARO SUS
# Dockerfile da nossa API .NET 8
# 1. Imagem com as ferramentas para compilar C#.
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# 2. Pasta de trabalho durante a compilacao.
WORKDIR /src

# 3. Copiamos o projeto e restauramos os pacotes.
COPY ["AmparoSus.Api/AmparoSus.Api.csproj", "AmparoSus.Api/"]
RUN dotnet restore "AmparoSus.Api/AmparoSus.Api.csproj"

# 4. Copiamos o codigo e publicamos a API.
COPY . .
RUN dotnet publish "AmparoSus.Api/AmparoSus.Api.csproj" \
    -c Release -o /app/publish --no-restore \
    /p:UseAppHost=false

# 5. Imagem mais leve para executar a API.
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final

# 6. Definimos a pasta de execucao.
WORKDIR /app

# 7. A API utilizara a porta 8080.
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

# 8. Copiamos a aplicacao compilada.
COPY --from=build /app/publish .

# 9. Executamos com usuario sem privilegios.
USER app

# 10. Iniciamos a API.
ENTRYPOINT ["dotnet", "AmparoSus.Api.dll"]
