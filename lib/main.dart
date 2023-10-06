import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flame/collisions.dart';

void main() {
  runApp(
    GameWidget(
      game: DemoGame(),
    ),
  );
}

class DemoGame extends FlameGame with PanDetector, HasCollisionDetection {
  static const String description = "demo game";

  late final TextComponent componentCounter;
  late final TextComponent scoreText;
  late final TextComponent panPosition;
  late final PlayerComponent player;
  int score = 0;

  final parallaxImages = [
    ParallaxImageData('bg.png'),
    ParallaxImageData('mountain-far.png'),
    ParallaxImageData('mountains.png'),
    ParallaxImageData('trees.png'),
    ParallaxImageData('foreground-trees.png'),
  ];

  @override
  Future<void> onLoad() async {
    // final parallax = await loadParallaxComponent(
    //   parallaxImages,
    //   baseVelocity: Vector2(20.0, 0.0),
    //   velocityMultiplierDelta: Vector2(1.8, 0.0),
    // );
    // add(parallax);

    add(player = PlayerComponent());
    addAll([
      FpsTextComponent(
        position: size - Vector2(0, 100),
        anchor: Anchor.bottomRight,
      ),
      scoreText = TextComponent(
        position: size - Vector2(0, 50),
        anchor: Anchor.bottomRight,
        priority: 1,
      ),
      componentCounter = TextComponent(
        position: size - Vector2(0, 25),
        anchor: Anchor.bottomRight,
        priority: 1,
      ),
      panPosition = TextComponent(
        position: size,
        anchor: Anchor.bottomRight,
        priority: 1,
      ),
    ]);

    // // add(EnemyComponent(
    // //     position: Vector2(
    // //   250,
    // //   50,
    // // )));

    add(EnemyCreator());
  }

  @override
  void update(double dt) {
    super.update(dt);
    scoreText.text = 'Score: $score';
    componentCounter.text = 'Components: ${children.length}';
  }

  @override
  void onPanStart(_) {}

  @override
  void onPanEnd(_) {}

  @override
  void onPanCancel() {}

  @override
  void onPanUpdate(DragUpdateInfo info) {
    panPosition.text = 'Click Position => ${info.delta.game}';
    //  print(info.delta.game);
    player.position += info.delta.game;
    // player.position[0] += info.delta.game[0];
  }

  void increaseScore() {
    score++;
  }
}

class PlayerComponent extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks {
  late TimerComponent bulletCreator;

  PlayerComponent()
      : super(
          size: Vector2(50, 75),
          position: Vector2(100, 500),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());

    animation = await gameRef.loadSpriteAnimation(
      'player.png',
      SpriteAnimationData.sequenced(
        stepTime: 0.2,
        amount: 4,
        textureSize: Vector2(32, 39),
      ),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    print("onCollision Start");
    if (other is EnemyComponent) {
      other.takeHit();
    }
  }

  void takeHit() {
    gameRef.add(ExplosionComponent(position: position));
  }
}

class EnemyComponent extends SpriteAnimationComponent with HasGameRef {
  late TimerComponent bulletCreator;
  static const speed = 100;
  static Vector2 initialSize = Vector2.all(24); // resize it
  EnemyComponent({required super.position})
      : super(size: initialSize, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    animation = await gameRef.loadSpriteAnimation(
      'spritesheet.png',
      SpriteAnimationData.sequenced(
        stepTime: 0.2,
        amount: 4,
        textureSize: Vector2(32, 39),
      ),
    );
    add(CircleHitbox(collisionType: CollisionType.passive, isSolid: true));
  }

  @override
  void update(double dt) {
    super.update(dt);
    y += speed * dt;
    if (y >= gameRef.size.y) {
      removeFromParent();
    }
  }

  void takeHit() {
    print("Take Hit");
    removeFromParent();

    gameRef.add(ExplosionComponent(position: position));
  }
}

class EnemyCreator extends TimerComponent with HasGameRef, CollisionCallbacks {
  final Random random = Random();
  final _halfWidth = EnemyComponent.initialSize.x / 2;

  EnemyCreator() : super(period: 0.05, repeat: true);

  @override
  void onTick() {
    gameRef.addAll(
      List.generate(
        5,
        (index) => EnemyComponent(
          position: Vector2(
            _halfWidth + (gameRef.size.x - _halfWidth) * random.nextDouble(),
            0,
          ),
        ),
      ),
    );
  }
}

class ExplosionComponent extends SpriteAnimationComponent with HasGameRef {
  ExplosionComponent({super.position})
      : super(
          size: Vector2.all(20),
          anchor: Anchor.center,
          removeOnFinish: true,
        );

  @override
  Future<void> onLoad() async {
    animation = await gameRef.loadSpriteAnimation(
      'explosion.png',
      SpriteAnimationData.sequenced(
        stepTime: 0.1,
        amount: 6,
        textureSize: Vector2.all(20),
        loop: false,
      ),
    );
  }
}
