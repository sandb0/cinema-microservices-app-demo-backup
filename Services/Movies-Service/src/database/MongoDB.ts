import { MongoClient, Db } from 'mongodb'

import { MongoDBSettings } from '../config/config'

class MongoDBConnection {
  /**
   * Singleton: store the only instance of `MongoDBConnection`.
   */
  public static instance: MongoDBConnection
  private db: Promise<Db>

  private constructor (settings: MongoDBSettings) {
    const uri = this.getMongoDBUri(settings)

    this.db = new Promise((resolve, reject) => {
      MongoClient.connect(uri, settings.options)
        .then(mongoClient => {
          resolve(mongoClient.db(settings.db))
        })
        .catch(reject)
    })
  }

  /**
   * Singleton: store the only instance of `MongoDBConnection`.
   * Connect in MongoDB database.
   *
   * @param settings MongoDB connection settings.
   */
  public static connect (settings: MongoDBSettings): MongoDBConnection {
    if (!MongoDBConnection.instance) {
      MongoDBConnection.instance = new MongoDBConnection(settings)
    }

    return MongoDBConnection.instance
  }

  public getDb (): Promise<Db> {
    return this.db
  }

  private getMongoDBUri (settings: MongoDBSettings): string {
    const uri = settings.servers
      .reduce((previous, current) =>
        previous + current + ',', 'mongodb://'
      )

    // return `${uri.substr(0, uri.length - 1)}/${settings.db}`
    return `${uri.substr(0, uri.length - 1)}`
  }
}

export { MongoDBConnection }
