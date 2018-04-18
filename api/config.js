var environment = "development";
if ( global && global.config && global.config.environment ) {
  environment = global.config.environment;
}
if ( process && process.env && process.env.NODE_ENV ) {
  environment = process.env.NODE_ENV;
}
module.exports = {
  environment: environment,
  // Host running the iNaturalist Rails app
  apiURL: process.env.INAT_APP_URL,
  // Whether the Rails app supports SSL requests. For local dev assume it does not
  apiHostSSL: false,
  writeHostSSL: false,
  elasticsearch: {
    host: "elastic:9200",
    geoPointField: "location",
    searchIndex: `${environment}_observations`,
    placeIndex: `${environment}_places`
  },
  database: {
    user: process.env.POSTGRES_USERNAME,
    host: process.env.POSTGRES_ADDRESS,
    port: 5432,
    geometry_field: "geom",
    srid: 4326,
    dbname: `inaturalist_${environment}`,
    password: process.env.POSTGRES_PASSWORD,
    ssl: false
  },
  tileSize: 512,
  debug: true,
  imageProcesing: {
    taxaFilePath: "",
    uploadsDir: "",
    tensorappURL: ""
  }
};
