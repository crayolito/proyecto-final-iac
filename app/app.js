import express from 'express';
import { createClient } from 'redis';

const app = express();
app.use(express.json());

const redisClient = createClient({
    url: `redis://${process.env.REDIS_HOST || "redis"}:${process.env.REDIS_PORT || 6379}`
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));
redisClient.on('connect', () => console.log('Conectado a Redis'));

let redisConnected = false;

if (process.env.NODE_ENV !== 'test') {
    redisClient.connect()
        .then(() => {
            redisConnected = true;
        })
        .catch((err) => {
            console.error('Error conectando a Redis:', err);
        });
}

app.get('/hola', (req, res) => {
    res.json({ mensaje: 'Hola Mundo' });
});

app.get('/visitas', async (req, res) => {
    try {
        if (!redisConnected) {
            return res.status(503).json({
                error: 'Redis no disponible',
                visitas: 'N/A'
            });
        }

        const visitas = await redisClient.incr('contador:visitas');

        res.json({
            mensaje: '¡Página de visitas!',
            visitas: visitas,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({
            error: 'Error al obtener visitas',
            detalles: error.message
        });
    }
});

app.post('/mensaje', async (req, res) => {
    try {
        if (!redisConnected) {
            return res.status(503).json({
                error: 'Redis no disponible'
            });
        }

        const { texto } = req.body;

        if (!texto) {
            return res.status(400).json({
                error: 'Se requiere el campo "texto"'
            });
        }

        const id = Date.now().toString();

        await redisClient.setEx(`mensaje:${id}`, 60, texto);

        res.json({
            mensaje: 'Mensaje guardado (expira en 60s)',
            id: id,
            texto: texto
        });
    } catch (error) {
        res.status(500).json({
            error: 'Error al guardar mensaje',
            detalles: error.message
        });
    }
});

app.get('/mensaje/:id', async (req, res) => {
    try {
        if (!redisConnected) {
            return res.status(503).json({
                error: 'Redis no disponible'
            });
        }

        const { id } = req.params;
        const texto = await redisClient.get(`mensaje:${id}`);

        if (!texto) {
            return res.status(404).json({
                error: 'Mensaje no encontrado o expirado'
            });
        }

        res.json({
            id: id,
            texto: texto
        });
    } catch (error) {
        res.status(500).json({
            error: 'Error al obtener mensaje',
            detalles: error.message
        });
    }
});

app.get('/health', async (req, res) => {
    const health = {
        status: 'ok',
        timestamp: new Date().toISOString(),
        redis: redisConnected ? 'conectado' : 'desconectado'
    };

    res.json(health);
});

export default app;
export { redisClient };
