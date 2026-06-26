# Demo app for Staubli JPO

## Install app

1) Install and setup docker & docker-compose

- Follow instructions at https://docs.docker.com/engine/install/ubuntu/ to install docker
- Don't forget the post-installation steps (see [here](https://docs.docker.com/engine/install/linux-postinstall/))

2) Install the Staubli JPO demo app

```bash
cd demo_staubli_med_2025

./app/install.sh

# Should show
$ ...
$ Installation complete. ...
```

## Launch the app

### Using the launcher

Go to the Ubuntu app launcher and look for the demo and click on it.
That's it.

### Manually

```bash
cd demo_staubli_med_2025

./app/app.sh
```

If you get an error like `"/staubli_jpo_demo" is already in use by container`:

```bash
# Remove old container if exists
docker rm -f staubli_jpo_demo
```
