const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const routes = require('./controllers');

app.set('view engine', 'ejs');
// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.set('view engine', 'ejs');
app.set('views', __dirname + '/views');

app.use('/', routes);
app.get('/', (req, res) => {
    const items = [
      "Ansible(Open Source-ish)",
      "KIND(Kubernetes-IN-Docker)",
      "KeyCloak IAM",
      "Node.js + Express",
      "Python + Flask",
      "Ruby On Rails",
      "Docker Compose",
      "RabbitMQ",
      "EasyAppointments",
      "Prometheus",
      "Grafana",
      "MariaDB",
      "phpMyAdmin",
      "BASH (Shell Scripting)"
      
      ];
      
      const callocs = [
        "/calendar-month",
        "/calendar-week",
        "/calendar-day",
        "/calendar-year",
        "/calendar-gen",
        "/list-gen",
        "/list-week",
        "/list-day",
        "/list-month",
        "/multi-month",
        "/multi-month-year",
        "/time-day",
        "/time-gen",
        "/time-week"

      ];
      
      const calnames = [
        "Calendar Month",
        "Calendar Week",
        "Calendar Day",
        "Calendar Year",
        "Calendar Generic",
        "List Generic",
        "List Week",
        "List Day",
        "List Month",
        "Multi Month",
        "Multi Month Year",
        "Time Day",
        "Time Generic",
        "Time Week"

      ];

      const rabmqitems = [
        "/publisher",
        "/consumer"
      ]

      const rabmqnames = [
        "Publisher",
        "Consumer"
      ]
      
    res.render('index1', {
        message: "Welcome to SLE, LLC - Development Environment on Kubernetes! v2", 
        message2: "The purpose of this project, is to be a self-contained single development stack and be the second or 'app1.js' version.",
        message3: "This incorporates using the following technologies as a single stack:",
        techstack: items,
        message4: "The README.md file also incorporates a tutorial, to recreate this entire setup, using a single ansible-playbook command.",
        calendarlocs: callocs,
        calendarnames: calnames,
        rmqlocs: rabmqitems,
        rmqnames: rabmqnames
    });
});

const PORT = 3100;
const ipAddr = '127.0.0.1';
app.listen(PORT, () => {
    console.log(`Server is running on http://${ipAddr}:${PORT}`);
});
