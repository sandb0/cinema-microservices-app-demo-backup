import { PoolConfig } from 'mysql'
import { MongoClientOptions } from 'mongodb'

export interface MongoDBSettings {
  db: string;
  servers: Array<string>;
  user?: string;
  pass?: string;
  options?: MongoClientOptions;
}

/**
 * MySQL settings.
 */
const mysqlSettings: PoolConfig = {
  connectionLimit: parseInt(process.env.MYSQL_CONN_LIMIT) || 10,
  host: process.env.MYSQL_HOST || 'mysql-service',
  user: process.env.MYSQL_USER || 'root',
  password: process.env.MYSQL_PASS || 'rootpasswd',
  database: process.env.MYSQL_DATABASE || 'movies'
}

function getMongoDBServers (defaultServers: Array<string>): Array<string> {
  const array = (process.env.MONGODB_SERVERS)
    ? process.env.MONGODB_SERVERS.split(',').map(server => server.trim())
    : defaultServers

  return array
}

/**
 * MongoDB settings.
 */
const mongodbSettings: MongoDBSettings = {
  db: process.env.MONGODB_DB || 'movies',
  servers: getMongoDBServers([
    'root:rootpasswd@mongodb-service:27017'
  ]),
  options: {
    useNewUrlParser: true,
    useUnifiedTopology: true
  }
}

export { mysqlSettings, mongodbSettings }
