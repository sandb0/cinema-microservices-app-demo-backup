import express from 'express'
import morgan from 'morgan'
import helmet from 'helmet'

class Application {
  public express: express.Application

  public constructor () {
    this.express = express()

    this.setMiddlewares()
    this.routes()
  }

  private setMiddlewares (): void {
    this.express.use(express.json())
    this.express.use(morgan('dev'))
    this.express.use(helmet())
  }

  private routes (): void {
    this.express.get('/', (request, response) => {
      console.log('OK!')
      return response.send('OK!')
    })
  }
}

const port = parseInt(process.env.PORT) || 3000
const app = new Application()
app.express.listen(port, () => {
  console.log(`Movies-Service listening on port ${port}.`)
})
