package com.alexisdaquiga.sombrasresidente2

import android.app.AlertDialog
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.activity.ComponentActivity
import kotlin.random.Random

class MainActivity : ComponentActivity() {

    private val handler = Handler(Looper.getMainLooper())

    private val missions = listOf(
        Mission(
            title = "El hospital inicial",
            target = 5,
            story = "Brian llega tarde al hospital y se ve obligado a falsificar la firma de la asistente para entregar el paquete médico.",
            objective = "Consigue que firmen el comprobante B7."
        ),
        Mission(
            title = "Carretera a Raccoon City",
            target = 5,
            story = "Brian acepta un encargo doble hacia Raccoon City. Habla con Michelle por teléfono antes de atropellar a una mujer cubierta de sangre.",
            objective = "Atraviesa la niebla y esquiva el peligro."
        ),
        Mission(
            title = "El patrullero y el bosque",
            target = 5,
            story = "El oficial escolta a Brian, pero su patrullero sufre un accidente. El policía muere y la mujer poseída ataca.",
            objective = "Escapa del ataque tras la muerte del oficial."
        ),
        Mission(
            title = "Casa abandonada",
            target = 6,
            story = "Brian salta una cerca eléctrica, sobrevive al perro zombi y encuentra una escopeta vacía.",
            objective = "Sobrevive al perro mutado y busca munición."
        ),
        Mission(
            title = "El túnel y el encuentro",
            target = 6,
            story = "En el túnel de autobuses abandonados, Brian es atacado por una niña mutada. Maxim y Carl lo rescatan.",
            objective = "Escapa del autobús infantil y del encuentro con Maxim y Carl."
        ),
        Mission(
            title = "Las alcantarillas y calles",
            target = 6,
            story = "Maxim desaparece y Carl es devorado por un perro mutante. Brian desciende a las alcantarillas.",
            objective = "Huye de la horda mutante subterránea."
        ),
        Mission(
            title = "Hospital de Raccoon City: escape final",
            target = 12,
            story = "Brian escala el hospital, esquiva a los bebés zombis mutantes y entrega el paquete para completar la cura definitiva.",
            objective = "Resiste en el cunero y entrega el paquete."
        )
    )

    private var level = 0
    private var health = 100
    private var ammo = 15
    private var objectiveCount = 0
    private var active = false
    private var gameOver = false
    private var won = false
    private var threat: Threat? = null
    private var threatToken = 0
    private var threatTask: Runnable? = null

    private lateinit var statsView: TextView
    private lateinit var missionView: TextView
    private lateinit var statusView: TextView

    private lateinit var startButton: Button
    private lateinit var tacticalButton: Button
    private lateinit var dodgeButton: Button
    private lateinit var actionButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        buildScreen()
        render()
        announce("Juego listo. ${currentMission().title}. ${currentMission().story} ${currentMission().objective}")
    }

    override fun onDestroy() {
        cancelThreat()
        super.onDestroy()
    }

    private fun buildScreen() {
        val scroll = ScrollView(this).apply {
            isFillViewport = true
            contentDescription = "Pantalla principal del juego"
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(20), dp(20), dp(28))
            setBackgroundColor(0xFF101820.toInt())
        }
        scroll.addView(root)

        root.addView(TextView(this).apply {
            text = "Sombras del Residente 2"
            textSize = 26f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dp(16))
            isAccessibilityHeading = true
        })

        statsView = bodyText().also { root.addView(it) }
        missionView = bodyText().also { root.addView(it) }
        statusView = bodyText().also { root.addView(it) }

        startButton = gameButton("Empezar / continuar") { startOrContinue() }
        root.addView(startButton)

        tacticalButton = gameButton("Juego táctico") { act(Threat.ATTACK) }
        root.addView(tacticalButton)

        dodgeButton = gameButton("Esquivar") { act(Threat.DODGE) }
        root.addView(dodgeButton)

        actionButton = gameButton("Acción / recoger") { act(Threat.ACTION) }
        root.addView(actionButton)

        root.addView(gameButton("Ayuda") { showHelp() })
        root.addView(gameButton("Apoyar al desarrollador") { openSupport() })
        root.addView(gameButton("Salir del juego") { finish() })

        setContentView(scroll)
    }

    private fun bodyText() = TextView(this).apply {
        textSize = 18f
        setTextColor(0xFFF2F4F8.toInt())
        setPadding(dp(4), dp(10), dp(4), dp(10))
        importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
    }

    private fun gameButton(label: String, onClick: () -> Unit) = Button(this).apply {
        text = label
        textSize = 18f
        minHeight = dp(56)
        isAllCaps = false
        contentDescription = label
        setOnClickListener { onClick() }
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            setMargins(0, dp(6), 0, dp(6))
        }
    }

    private fun startOrContinue() {
        when {
            won -> announce("La historia ya terminó. Gracias por jugar.")
            gameOver -> {
                health = 100
                ammo = 15
                objectiveCount = 0
                gameOver = false
                beginMission("Reintentando nivel ${level + 1}.")
            }
            active -> announce("La misión está en curso. ${currentMission().objective}")
            else -> beginMission("Comienza el nivel ${level + 1}.")
        }
    }

    private fun beginMission(prefix: String) {
        active = true
        render()
        val mission = currentMission()
        announce("$prefix ${mission.title}. ${mission.story} Objetivo: ${mission.objective}")
        scheduleThreat(2200)
    }

    private fun scheduleThreat(delay: Long) {
        if (!active || gameOver || won) return
        threatTask?.let(handler::removeCallbacks)

        val token = ++threatToken
        threatTask = Runnable {
            if (!active || gameOver || won || token != threatToken) return@Runnable

            val kind = when (Random.nextInt(100)) {
                in 0..34 -> Threat.ATTACK
                in 35..64 -> Threat.DODGE
                else -> Threat.ACTION
            }

            threat = kind

            val prompt = when (kind) {
                Threat.ATTACK -> "Amenaza detectada. Pulsa Juego táctico."
                Threat.DODGE -> "Un enemigo se abalanza. Pulsa Esquivar."
                Threat.ACTION -> "Hay un objetivo o suministros cerca. Pulsa Acción / recoger."
            }

            render()
            announce(prompt)

            val window = reactionWindowMillis()
            val missedToken = threatToken

            threatTask = Runnable {
                if (active && threat != null && missedToken == threatToken) {
                    threat = null
                    health = (health - 25).coerceAtLeast(0)
                    render()
                    announce("Brian ha sido herido. Salud: $health por ciento.")
                    if (health == 0) failMission() else scheduleThreat(1800)
                }
            }

            handler.postDelayed(threatTask!!, window)
        }

        handler.postDelayed(threatTask!!, delay)
    }

    private fun reactionWindowMillis(): Long {
        val byLevel = when {
            level >= 6 -> 2000L
            level >= 4 -> 2500L
            level >= 2 -> 3000L
            else -> 4000L
        }
        return if (health <= 50) (byLevel - 500L).coerceAtLeast(1200L) else byLevel
    }

    private fun act(action: Threat) {
        if (!active || gameOver || won) {
            announce("Pulsa Empezar o continuar para iniciar la misión.")
            return
        }

        val currentThreat = threat

        if (currentThreat == null) {
            if (action == Threat.ACTION) searchSupplies() else {
                announce("No hay una amenaza activa. Espera el siguiente aviso.")
            }
            render()
            return
        }

        if (action != currentThreat) {
            announce("Esa acción no responde a la amenaza actual. Escucha el aviso y vuelve a intentarlo.")
            return
        }

        cancelThreat()

        when (action) {
            Threat.ATTACK -> {
                if (ammo > 0) {
                    ammo--
                    announce("Ataque táctico acertado. Munición restante: $ammo.")
                } else {
                    health = (health - 10).coerceAtLeast(0)
                    announce("No queda munición. Brian recibió daño. Salud: $health por ciento.")
                }
            }

            Threat.DODGE -> {
                announce("Esquivaste el ataque.")
            }

            Threat.ACTION -> {
                objectiveCount++
                announce("Objetivo asegurado. ${progressText()}")
            }
        }

        render()

        when {
            health <= 0 -> failMission()
            objectiveCount >= currentMission().target -> completeMission()
            else -> scheduleThreat(1800)
        }
    }

    private fun searchSupplies() {
        when (Random.nextInt(100)) {
            in 0..29 -> {
                ammo += 5
                announce("Encontraste cinco cartuchos. Munición: $ammo.")
            }
            in 30..49 -> {
                val before = health
                health = (health + 25).coerceAtMost(100)
                announce(
                    if (health == before) {
                        "Encontraste suministros, pero tu salud ya está al máximo."
                    } else {
                        "Encontraste un botiquín. Salud recuperada a $health por ciento."
                    }
                )
            }
            else -> announce("No encontraste suministros. Continúa buscando.")
        }

        render()
        if (active) scheduleThreat(1800)
    }

    private fun completeMission() {
        cancelThreat()
        active = false
        objectiveCount = 0
        level++

        if (level >= missions.size) {
            won = true
            render()
            announce("Misión terminada. Brian entrega el paquete en el laboratorio. Gracias por jugar.")
        } else {
            render()
            val next = currentMission()
            announce("Nivel superado. Siguiente nivel: ${next.title}. ${next.story} Objetivo: ${next.objective}. Pulsa Empezar o continuar cuando estés listo.")
        }
    }

    private fun failMission() {
        cancelThreat()
        active = false
        gameOver = true
        render()
        startButton.text = "Reintentar nivel"
        announce("Brian ha caído en misión. Pulsa Reintentar nivel para volver a intentarlo.")
    }

    private fun render() {
        val mission = currentMission()
        statsView.text = """
            Estadísticas
            Salud: $health por ciento
            Munición: $ammo
            Objetivos: $objectiveCount de ${mission.target}
            Nivel: ${level + 1} de ${missions.size}
        """.trimIndent()

        missionView.text = """
            Resumen del nivel:
            ${mission.title}
            ${mission.story}
            Qué hacer: ${mission.objective}
        """.trimIndent()

        statusView.text = when {
            won -> "Estado: historia completada."
            gameOver -> "Estado: fallaste. Puedes reintentar el nivel."
            active -> "Estado: misión en curso. ${progressText()}"
            else -> "Estado: listo para empezar o continuar."
        }

        if (!gameOver && !won) {
            startButton.text = if (active) "Continuar misión" else "Empezar / continuar"
        }

        val enabled = active && !gameOver && !won
        tacticalButton.isEnabled = enabled
        dodgeButton.isEnabled = enabled
        actionButton.isEnabled = enabled

        if (enabled && health <= 50) {
            statusView.text = "Estado: salud crítica. Los enemigos están más agresivos. ${progressText()}"
        }
    }

    private fun currentMission() = missions[level.coerceIn(0, missions.lastIndex)]
    private fun progressText() = "Objetivos completados: $objectiveCount de ${currentMission().target}."

    private fun showHelp() {
        AlertDialog.Builder(this)
            .setTitle("Ayuda")
            .setMessage(
                "Escucha los avisos del lector de pantalla y responde con el botón indicado. " +
                    "Juego táctico consume munición; Esquivar evita ataques; Acción / recoger responde a objetivos o busca suministros. " +
                    "Los botiquines recuperan salud. Al llegar al 50% de salud, las amenazas dan menos tiempo para reaccionar."
            )
            .setPositiveButton("Entendido", null)
            .show()
    }

    private fun openSupport() {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.tiktok.com/@alexisdaquiga"))
        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            announce("No se pudo abrir el enlace de apoyo.")
        }
    }

    private fun announce(message: String) {
        statusView.text = message
        statusView.sendAccessibilityEvent(AccessibilityEvent.TYPE_ANNOUNCEMENT)
        statusView.announceForAccessibility(message)
    }

    private fun cancelThreat() {
        threatToken++
        threatTask?.let(handler::removeCallbacks)
        threatTask = null
        threat = null
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    private data class Mission(
        val title: String,
        val target: Int,
        val story: String,
        val objective: String
    )

    private enum class Threat {
        ATTACK,
        DODGE,
        ACTION
    }
}