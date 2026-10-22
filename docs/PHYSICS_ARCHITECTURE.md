# Physics architecture

Use Godot/Jolt for ordinary scene interaction, collision queries, and impact presentation. Keep the virtual flight solver independent of rigid-body collision simulation so it can advance deterministically and provide repeatable telemetry.

The flight model will be implemented and validated as a separate game system. This repository starter does not yet claim a validated high-speed flight model.
