import {
  createPool,
  Pool, PoolConfig, MysqlError
} from 'mysql'

class MySQLPoolConnection {
  /**
   * Singleton: store the only instance of `MySQLPoolConnection`.
   */
  private static instance: MySQLPoolConnection
  private pool: Pool

  private constructor (settings: PoolConfig) {
    this.pool = createPool(settings)

    // Connection error handling.
    this.pool.getConnection((error: MysqlError) => {
      if (error) {
        throw error
      }
    })
  }

  /**
   * Singleton: store the only instance of `MySQLPoolConnection`.
   * Connect in MySQL database.
   *
   * @param settings MySQL pool connection settings.
   */
  public static connect (settings: PoolConfig): MySQLPoolConnection {
    if (!MySQLPoolConnection.instance) {
      MySQLPoolConnection.instance = new MySQLPoolConnection(settings)
    }

    return MySQLPoolConnection.instance
  }

  public getPool (): Pool {
    return this.pool
  }
}

export { MySQLPoolConnection }
