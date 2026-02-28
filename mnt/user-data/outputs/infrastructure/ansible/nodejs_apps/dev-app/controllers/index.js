const express = require('express');
const amqp = require('amqplib');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const MarkdownIt = require('markdown-it');
const md = new MarkdownIt();

const MAX_MESSAGES = 5;
let messages = [];

router.get('/calendar-month', (req, res) => {
  res.render('calendar-month');
});

router.get('/calendar-week', (req, res) => {
  res.render('calendar-week');
});

router.get('/calendar-day', (req, res) => {
  res.render('calendar-day');
});

router.get('/calendar-year', (req, res) => {
  res.render('calendar-year');
});

router.get('/calendar-gen', (req, res) => {
  res.render('calendar-gen');
});

router.get('/list-day', (req, res) => {
  res.render('list-day');
});

router.get('/list-month', (req, res) => {
  res.render('list-month');
});

router.get('/list-week', (req, res) => {
  res.render('list-week');
});

router.get('/list-gen', (req, res) => {
  res.render('list-gen');
});

router.get('/multi-month', (req, res) => {
  res.render('multi-month');
});

router.get('/multi-month-year', (req, res) => {
  res.render('multi-month-year');
});

router.get('/time-day', (req, res) => {
  res.render('time-day');
});

router.get('/time-week', (req, res) => {
  res.render('time-week');
});

router.get('/time-gen', (req, res) => {
  res.render('time-gen');
});


router.get('/consumer', (req, res) => {
  res.render('consumer'); // Render the EJS view
});

router.get('/consume', async (req, res) => {
  try {
    const connection = await amqp.connect('amqp://rmq.dev.ans:3a84rg375fgHDHID@localhost:5672');
    const nodechan = await connection.createChannel();
    const queue = 'testing-queue.1';

    await nodechan.assertQueue(queue);
    nodechan.consume(queue, (message) => {
      if (message !== null) {
        console.log(`Received: ${message.content.toString()}`);
        
        // Acknowledge the message
        nodechan.ack(message);
      }
    });

    res.redirect('/consumer');
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Error consuming message');
  }
});

  
router.get('/message', (req, res) => {
    res.render('message', { messages: messages });
});

router.post('/message', (req, res) => {
    const newMessage = req.body.message;
    messages.unshift(newMessage); // Add new message to the beginning of the array

    if (messages.length > MAX_MESSAGES) {
        messages.pop(); // Remove the oldest message if array exceeds the limit
    }

    res.redirect('/message');
});

router.get('/publisher', (req, res) => {
    res.render('publisher'); // Render the EJS view
  });
  
  router.post('/publish', async (req, res) => {
    try {
      const connection = await amqp.connect('amqp://rmq.dev.ans:3a84rg375fgHDHID@localhost:5672');
      const nodechan = await connection.createChannel();
      const queue = 'testing-queue.1';
      const newmessage = 'Hello from NodeJS Publisher!';
  
      await nodechan.assertQueue(queue);
      nodechan.sendToQueue(queue, Buffer.from(newmessage));
  
      console.log(`Sent: ${newmessage}`);
      setTimeout(() => {
        connection.close();
      }, 1000);
  
      res.redirect('/publisher');
    } catch (error) {
      console.error('Error:', error);
      res.status(500).send('Error publishing message');
    }
  });

router.get('/readme', (req, res) => {
    const readmePath = path.join(__dirname, '../files/README.md');
    const readmeContent = fs.readFileSync(readmePath, 'utf-8');
    const renderedContent = md.render(readmeContent);
    res.render('readme', { readmeContent: renderedContent });
});

module.exports = router;
