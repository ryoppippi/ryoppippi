#!/usr/bin/env node

import open from "open";
import config from "./config.json" with { type: "json" };

await open(config.url);
