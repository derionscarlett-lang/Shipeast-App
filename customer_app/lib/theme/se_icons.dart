import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// ShipEast Design System — Icon façade (SEDS §1.5).
///
/// Phosphor Icons are the single icon family across the whole app. Every screen
/// references icons through this class (`SeIcons.home`, `SeIcons.heartFill`, …)
/// so the app has ONE icon vocabulary and ONE point of dependency on the
/// underlying package. Regular weight is the default; Fill is used for active
/// nav / selected states.
class SeIcons {
  SeIcons._();

  // Bottom navigation
  static const IconData home = PhosphorIconsRegular.house;
  static const IconData homeFill = PhosphorIconsFill.house;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData searchFill = PhosphorIconsFill.magnifyingGlass;
  static const IconData orders = PhosphorIconsRegular.receipt;
  static const IconData ordersFill = PhosphorIconsFill.receipt;
  static const IconData bell = PhosphorIconsRegular.bell;
  static const IconData bellFill = PhosphorIconsFill.bell;
  static const IconData user = PhosphorIconsRegular.user;
  static const IconData userFill = PhosphorIconsFill.user;

  // Categories
  static const IconData food = PhosphorIconsRegular.forkKnife;
  static const IconData grocery = PhosphorIconsRegular.basket;
  static const IconData packages = PhosphorIconsRegular.package;
  static const IconData pharmacy = PhosphorIconsRegular.pill;
  static const IconData foodFill = PhosphorIconsFill.forkKnife;
  static const IconData groceryFill = PhosphorIconsFill.basket;
  static const IconData packagesFill = PhosphorIconsFill.package;
  static const IconData pharmacyFill = PhosphorIconsFill.pill;

  // Home / merchant
  static const IconData location = PhosphorIconsRegular.mapPin;
  static const IconData locationFill = PhosphorIconsFill.mapPin;
  static const IconData locationLine = PhosphorIconsRegular.mapPinLine;
  static const IconData plane = PhosphorIconsRegular.airplaneTilt;
  static const IconData storefront = PhosphorIconsRegular.storefront;
  static const IconData heart = PhosphorIconsRegular.heart;
  static const IconData heartFill = PhosphorIconsFill.heart;
  static const IconData star = PhosphorIconsFill.star;
  static const IconData starOutline = PhosphorIconsRegular.star;
  static const IconData clock = PhosphorIconsRegular.clock;
  static const IconData bike = PhosphorIconsRegular.motorcycle;
  static const IconData scales = PhosphorIconsRegular.scales;
  static const IconData box = PhosphorIconsRegular.package;

  // Cart / checkout / payment
  static const IconData cart = PhosphorIconsRegular.shoppingCart;
  static const IconData cartFill = PhosphorIconsFill.shoppingCart;
  static const IconData creditCard = PhosphorIconsRegular.creditCard;
  static const IconData cash = PhosphorIconsRegular.money;
  static const IconData tag = PhosphorIconsRegular.tag;
  static const IconData note = PhosphorIconsRegular.note;

  // Actions
  static const IconData plus = PhosphorIconsRegular.plus;
  static const IconData minus = PhosphorIconsRegular.minus;
  static const IconData close = PhosphorIconsRegular.x;
  static const IconData check = PhosphorIconsRegular.check;
  static const IconData checkCircle = PhosphorIconsFill.checkCircle;
  static const IconData trash = PhosphorIconsRegular.trash;
  static const IconData edit = PhosphorIconsRegular.pencilSimple;
  static const IconData camera = PhosphorIconsRegular.camera;
  static const IconData phone = PhosphorIconsFill.phone;
  static const IconData copy = PhosphorIconsRegular.copy;
  static const IconData share = PhosphorIconsRegular.shareNetwork;

  // Chevrons / arrows
  static const IconData caretRight = PhosphorIconsRegular.caretRight;
  static const IconData caretLeft = PhosphorIconsRegular.caretLeft;
  static const IconData caretDown = PhosphorIconsRegular.caretDown;
  static const IconData arrowLeft = PhosphorIconsRegular.arrowLeft;
  static const IconData arrowRight = PhosphorIconsRegular.arrowRight;

  // Profile / menu
  static const IconData settings = PhosphorIconsRegular.gearSix;
  static const IconData signOut = PhosphorIconsRegular.signOut;
  static const IconData shield = PhosphorIconsRegular.shieldCheck;
  static const IconData help = PhosphorIconsRegular.question;
  static const IconData chat = PhosphorIconsRegular.chatCircle;
  static const IconData addresses = PhosphorIconsRegular.mapPinLine;
  static const IconData sun = PhosphorIconsRegular.sun;
  static const IconData moon = PhosphorIconsRegular.moon;

  // Auth
  static const IconData envelope = PhosphorIconsRegular.envelopeSimple;
  static const IconData lock = PhosphorIconsRegular.lockSimple;
  static const IconData eye = PhosphorIconsRegular.eye;
  static const IconData eyeSlash = PhosphorIconsRegular.eyeSlash;
  static const IconData google = PhosphorIconsRegular.googleLogo;
  static const IconData userCircle = PhosphorIconsRegular.userCircle;

  // States / feedback
  static const IconData warning = PhosphorIconsFill.warning;
  static const IconData warningCircle = PhosphorIconsFill.warningCircle;
  static const IconData info = PhosphorIconsFill.info;
  static const IconData noConnection = PhosphorIconsRegular.wifiSlash;
  static const IconData filter = PhosphorIconsRegular.funnel;
  static const IconData list = PhosphorIconsRegular.listBullets;
  static const IconData rocket = PhosphorIconsRegular.rocketLaunch;
  static const IconData sparkle = PhosphorIconsFill.sparkle;
  static const IconData confetti = PhosphorIconsRegular.confetti;
}
